-- =============================================
-- SCRIPT SQL TẠO BẢNG CHO HỆ THỐNG QUẢN LÝ BÃI ĐỖ XE
-- Supabase (PostgreSQL) - Hỗ trợ Auth, OpenStreetMap (lat/long), slot trực quan, đánh giá minh bạch
-- =============================================

-- Bật extension nếu chưa có (Supabase đã hỗ trợ sẵn)
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- 1. profiles: Thông tin User (liên kết với Supabase Auth)
-- =============================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin', 'parking_owner')),
    full_name TEXT,
    balance NUMERIC(12,2) DEFAULT 0 CHECK (balance >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- =============================================
-- 2. vehicles: Thông tin xe của user
-- =============================================
CREATE TABLE IF NOT EXISTS public.vehicles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('car', 'motorcycle')), -- ô tô / xe máy
    name TEXT NOT NULL,                    -- ví dụ: Toyota Matrix, Honda Wave...
    license_plate TEXT NOT NULL UNIQUE,    -- biển số xe
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- =============================================
-- 3. parking_lots: Bãi đỗ xe (hỗ trợ OpenStreetMap qua lat/long)
-- =============================================
CREATE TABLE IF NOT EXISTS public.parking_lots (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    location TEXT,                         -- địa chỉ chi tiết (text)
    latitude DOUBLE PRECISION NOT NULL,    -- dùng để tìm đường gần nhất với OpenStreetMap
    longitude DOUBLE PRECISION NOT NULL,
    avg_rating NUMERIC(3,2) DEFAULT 0 CHECK (avg_rating BETWEEN 0 AND 5),
    total_reviews INTEGER DEFAULT 0 CHECK (total_reviews >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Index hỗ trợ tìm bãi gần nhất (OpenStreetMap + khoảng cách)
CREATE INDEX IF NOT EXISTS idx_parking_lots_location 
ON public.parking_lots (latitude, longitude);

-- =============================================
-- 4. parking_prices: Bảng giá theo thời gian
-- =============================================
CREATE TABLE IF NOT EXISTS public.parking_prices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    parking_lot_id UUID REFERENCES public.parking_lots(id) ON DELETE CASCADE NOT NULL,
    duration_type TEXT NOT NULL,           -- ví dụ: '30m', '1h', '2h', '4h', '1d', 'night'
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    UNIQUE (parking_lot_id, duration_type)
);

-- =============================================
-- 5. slots: Chỗ đỗ xe (trực quan, có tên slot như B1, C1...)
-- =============================================
CREATE TABLE IF NOT EXISTS public.slots (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    parking_lot_id UUID REFERENCES public.parking_lots(id) ON DELETE CASCADE NOT NULL,
    slot_name TEXT NOT NULL,               -- ví dụ: A01, B12, C05...
    status TEXT NOT NULL DEFAULT 'available' 
        CHECK (status IN ('available', 'occupied', 'reserved', 'maintenance')),
    UNIQUE (parking_lot_id, slot_name)
);

-- Index cho slot theo bãi
CREATE INDEX IF NOT EXISTS idx_slots_parking_lot 
ON public.slots (parking_lot_id);

-- =============================================
-- 6. bookings: Đặt chỗ / vé đỗ xe
-- =============================================
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    slot_id UUID REFERENCES public.slots(id) ON DELETE SET NULL,
    vehicle_id UUID REFERENCES public.vehicles(id) ON DELETE SET NULL,
    start_time TIMESTAMPTZ NOT NULL,
    duration INTERVAL NOT NULL,            -- thời gian đỗ (ví dụ: '2 hours', '30 minutes')
    payment_method TEXT CHECK (payment_method IN ('balance', 'cash', 'card', 'online')),
    ticket_number TEXT UNIQUE,             -- mã vé độc nhất (có thể generate ở app)
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    status TEXT DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'completed', 'cancelled', 'expired'))
);

-- Index hỗ trợ query nhanh
CREATE INDEX IF NOT EXISTS idx_bookings_user ON public.bookings (user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_slot ON public.bookings (slot_id);
CREATE INDEX IF NOT EXISTS idx_bookings_time ON public.bookings (start_time);

-- =============================================
-- 7. ratings: Hệ thống đánh giá minh bạch
-- =============================================
CREATE TABLE IF NOT EXISTS public.ratings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    parking_lot_id UUID REFERENCES public.parking_lots(id) ON DELETE CASCADE NOT NULL,
    stars INTEGER NOT NULL CHECK (stars BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Đảm bảo 1 user chỉ đánh giá 1 lần cho 1 bãi (minh bạch)
CREATE UNIQUE INDEX IF NOT EXISTS idx_ratings_user_parking 
ON public.ratings (user_id, parking_lot_id);

-- =============================================
-- TRIGGER: Cập nhật avg_rating & total_reviews tự động (minh bạch)
-- =============================================
CREATE OR REPLACE FUNCTION public.update_parking_lot_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.parking_lots
    SET 
        avg_rating = (
            SELECT ROUND(AVG(stars)::numeric, 2)
            FROM public.ratings 
            WHERE parking_lot_id = NEW.parking_lot_id
        ),
        total_reviews = (
            SELECT COUNT(*) 
            FROM public.ratings 
            WHERE parking_lot_id = NEW.parking_lot_id
        )
    WHERE id = NEW.parking_lot_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger chạy sau khi insert/update/delete rating
DROP TRIGGER IF EXISTS trigger_update_rating ON public.ratings;
CREATE TRIGGER trigger_update_rating
AFTER INSERT OR UPDATE OR DELETE ON public.ratings
FOR EACH ROW EXECUTE FUNCTION public.update_parking_lot_rating();
-- =============================================
-- TRIGGER CHO BOOKINGS - Quản lý trạng thái slot
-- =============================================

CREATE OR REPLACE FUNCTION public.handle_booking_slot_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Trường hợp INSERT booking mới
    IF TG_OP = 'INSERT' THEN
        IF NEW.status = 'confirmed' THEN
            UPDATE public.slots
            SET status = 'reserved'
            WHERE id = NEW.slot_id
              AND status = 'available';  -- Chỉ cho phép nếu còn trống

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Slot không khả dụng hoặc đã được đặt/reserved';
            END IF;
        END IF;
        RETURN NEW;
    END IF;

    -- Trường hợp UPDATE status của booking
    IF TG_OP = 'UPDATE' THEN
        -- Chỉ xử lý khi status thay đổi
        IF OLD.status = NEW.status THEN
            RETURN NEW;
        END IF;

        IF NEW.status = 'completed' THEN
            UPDATE public.slots
            SET status = 'available'
            WHERE id = NEW.slot_id;
        ELSIF NEW.status = 'cancelled' THEN
            UPDATE public.slots
            SET status = 'available'
            WHERE id = NEW.slot_id;
        ELSIF NEW.status = 'confirmed' THEN
            UPDATE public.slots
            SET status = 'reserved'
            WHERE id = NEW.slot_id
              AND status = 'available';
        END IF;

        RETURN NEW;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Tạo Trigger
DROP TRIGGER IF EXISTS trigger_handle_booking_slot ON public.bookings;
CREATE TRIGGER trigger_handle_booking_slot
AFTER INSERT OR UPDATE OF status ON public.bookings
FOR EACH ROW EXECUTE FUNCTION public.handle_booking_slot_status();
-- =============================================
-- FUNCTION TÍNH KHOẢNG CÁCH (Haversine) - Đơn vị: mét
-- =============================================
CREATE OR REPLACE FUNCTION public.calculate_distance(
    lat1 DOUBLE PRECISION,
    lon1 DOUBLE PRECISION,
    lat2 DOUBLE PRECISION,
    lon2 DOUBLE PRECISION
)
RETURNS DOUBLE PRECISION AS $$
DECLARE
    R DOUBLE PRECISION := 6371000; -- Bán kính Trái Đất (mét)
    dlat DOUBLE PRECISION;
    dlon DOUBLE PRECISION;
    a DOUBLE PRECISION;
    c DOUBLE PRECISION;
BEGIN
    dlat := RADIANS(lat2 - lat1);
    dlon := RADIANS(lon2 - lon1);
    a := SIN(dlat/2)^2 + COS(RADIANS(lat1)) * COS(RADIANS(lat2)) * SIN(dlon/2)^2;
    c := 2 * ATAN2(SQRT(a), SQRT(1 - a));
    RETURN R * c;  -- Trả về khoảng cách mét
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =============================================
-- FUNCTION TÌM BÃI ĐỖ GẦN NHẤT (có giới hạn khoảng cách)
-- Ví dụ gọi: SELECT * FROM get_nearby_parking_lots(10.8231, 106.6297, 5000, 10);
-- (lat, lon của người dùng, bán kính 5km, top 10)
-- =============================================
CREATE OR REPLACE FUNCTION public.get_nearby_parking_lots(
    user_lat DOUBLE PRECISION,
    user_lon DOUBLE PRECISION,
    max_distance_meters DOUBLE PRECISION DEFAULT 10000,  -- mặc định 10km
    limit_count INTEGER DEFAULT 20
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    location TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    avg_rating NUMERIC(3,2),
    total_reviews INTEGER,
    distance_meters DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pl.id,
        pl.name,
        pl.location,
        pl.latitude,
        pl.longitude,
        pl.avg_rating,
        pl.total_reviews,
        public.calculate_distance(user_lat, user_lon, pl.latitude, pl.longitude) AS distance_meters
    FROM public.parking_lots pl
    WHERE public.calculate_distance(user_lat, user_lon, pl.latitude, pl.longitude) <= max_distance_meters
    ORDER BY distance_meters ASC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;
-- =============================================
-- BẬT RLS CHO TẤT CẢ CÁC BẢNG
-- =============================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parking_lots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parking_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;

-- =============================================
-- POLICIES CHI TIẾT
-- =============================================

-- 1. Profiles
CREATE POLICY "Users can view and update own profile" ON public.profiles
FOR ALL TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

CREATE POLICY "Admins can view all profiles" ON public.profiles
FOR SELECT TO authenticated
USING ( (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin' );

-- 2. Vehicles (User chỉ quản lý xe của mình)
CREATE POLICY "Users manage own vehicles" ON public.vehicles
FOR ALL TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 3. Parking Lots (Công khai xem, chỉ admin/parking_owner mới sửa)
CREATE POLICY "Anyone can view parking lots" ON public.parking_lots
FOR SELECT TO authenticated, anon
USING (true);

CREATE POLICY "Admins and owners can manage parking lots" ON public.parking_lots
FOR ALL TO authenticated
USING ( 
    (SELECT role FROM public.profiles WHERE id = auth.uid()) IN ('admin', 'parking_owner')
);

-- 4. Parking Prices (Theo parking lot)
CREATE POLICY "Anyone can view prices" ON public.parking_prices
FOR SELECT TO authenticated, anon
USING (true);

CREATE POLICY "Owners can manage prices" ON public.parking_prices
FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.parking_lots pl 
        WHERE pl.id = parking_prices.parking_lot_id 
        AND (SELECT role FROM public.profiles WHERE id = auth.uid()) IN ('admin', 'parking_owner')
    )
);

-- 5. Slots (Xem công khai để hiển thị bản đồ/slot, chỉ owner cập nhật)
CREATE POLICY "Anyone can view slots" ON public.slots
FOR SELECT TO authenticated, anon
USING (true);

CREATE POLICY "Owners can manage slots" ON public.slots
FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.parking_lots 
        WHERE id = slots.parking_lot_id 
        AND (SELECT role FROM public.profiles WHERE id = auth.uid()) IN ('admin', 'parking_owner')
    )
);

-- 6. Bookings (User chỉ thấy và quản lý booking của mình)
CREATE POLICY "Users manage own bookings" ON public.bookings
FOR ALL TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 7. Ratings (Minh bạch: User chỉ đánh giá 1 lần, ai cũng xem được rating)
CREATE POLICY "Anyone can view ratings" ON public.ratings
FOR SELECT TO authenticated, anon
USING (true);

CREATE POLICY "Users can create and update own rating" ON public.ratings
FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own rating" ON public.ratings
FOR UPDATE TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- (Không cho delete rating để giữ minh bạch)