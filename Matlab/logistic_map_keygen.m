function bin_key = logistic_map_keygen(x0, r, seq_length)
    % x0: مقدار اولیه (Initial Condition)
    % r: پارامتر کنترلی (Control Parameter)
    % seq_length: طول دنباله مورد نیاز (برابر با طول پیام)
    
    x = zeros(1, seq_length);
    x(1) = r * x0 * (1 - x0);
    
    % تولید دنباله آشوب‌گونه
    for i = 2:seq_length
        x(i) = r * x(i-1) * (1 - x(i-1));
    end
    
    % تبدیل مقادیر اعشاری به دنباله باینری (۰ و ۱) برای عملیات XOR
    % استفاده از آستانه میانگین برای باینری‌سازی
    threshold = mean(x);
    bin_key = (x >= threshold); 
end
