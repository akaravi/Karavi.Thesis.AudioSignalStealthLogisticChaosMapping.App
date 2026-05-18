function [stego_audio, extracted_msg] = embed_extract_data(cover_audio, binary_msg, bin_key)
    % cover_audio: سیگنال صوتی میزبان
    % binary_msg: پیام باینری اصلی
    % bin_key: کلید باینری تولید شده توسط لاجستیک
    
    msg_length = length(binary_msg);
    
    % 1. رمزنگاری پیام با استفاده از عملگر XOR
    encrypted_msg = xor(binary_msg(:), bin_key(:));
    
    % آماده‌سازی سیگنال صوتی برای اعمال bitset (تبدیل به عدد صحیح 16 بیتی)
    cover_int = int16(cover_audio * 32767);
    stego_int = cover_int;
    
    % 2. فرآیند جاسازی (Embedding) در بیت کم‌ارزش (LSB)
    for i = 1:msg_length
        stego_int(i) = bitset(stego_int(i), 1, encrypted_msg(i));
    end
    
    % تبدیل مجدد به فرمت استاندارد صوتی (Double بین -1 و 1)
    stego_audio = double(stego_int) / 32767;
    
    % -------------------------------------------------------------
    % 3. فرآیند استخراج (Extraction)
    extracted_enc_msg = false(msg_length, 1);
    for i = 1:msg_length
        extracted_enc_msg(i) = bitget(stego_int(i), 1);
    end
    
    % 4. رمزگشایی پیام (اعمال مجدد XOR)
    extracted_msg = xor(extracted_enc_msg(:), bin_key(:));
end
