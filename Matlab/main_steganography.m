% =========================================================================
% Main Script: Audio Steganography using Deep Autoencoder & Logistic Map
% =========================================================================
clc; clear; close all;

%% 1. تنظیمات اولیه و پارامترها
r_param = 3.99;       % پارامتر کنترلی لاجستیک (آشوب کامل)
x0_param = 0.45;      % مقدار اولیه لاجستیک
bit_depth = 16;       % عمق بیت سیگنال صوتی

%% 2. بارگذاری سیگنال صوتی و تولید پیام
% (در اینجا یک سیگنال تصادفی به عنوان نمونه ساخته می‌شود، شما فایل صوتی خود را audioread کنید)
Fs = 44100;
t = 0:1/Fs:1;
cover_audio = sin(2*pi*440*t)'; % یک سیگنال سینوسی ساده به عنوان میزبان
N = length(cover_audio);

% تولید پیام تصادفی باینری (مثلاً 1000 بیت)
msg_len = 1000;
original_msg = randi([0 1], msg_len, 1);

%% 3. پیش‌پردازش و شبکه عصبی (اختیاری در مسیر اصلی جاسازی، برای فشرده‌سازی)
% در صورت نیاز به استفاده مستقیم از خروجی اتواینکدر به عنوان میزبان:
% [autoenc_net, reconstructed_audio] = train_deep_autoencoder(cover_audio');
% cover_audio = reconstructed_audio'; 

%% 4. تولید کلید آشوب‌گونه لاجستیک
key_seq = logistic_map_keygen(x0_param, r_param, msg_len);

%% 5. جاسازی و استخراج پیام
[stego_audio, extracted_msg] = embed_extract_data(cover_audio, original_msg, key_seq);

% تولید یک سیگنال استگو با کلید اندکی متفاوت برای تست امنیت (NPCR/UACI)
key_seq_diff = logistic_map_keygen(x0_param + 1e-10, r_param, msg_len);
[stego_audio_diff, ~] = embed_extract_data(cover_audio, original_msg, key_seq_diff);

%% 6. ارزیابی نتایج
disp('در حال محاسبه معیارهای ارزیابی...');
[snr_v, psnr_v, ber_v, npcr_v, uaci_v] = evaluate_stego(...
    cover_audio, stego_audio, original_msg, extracted_msg, stego_audio, stego_audio_diff, bit_depth);

%% 7. رسم نمودارها
figure;
subplot(2,1,1);
plot(t(1:1000), cover_audio(1:1000)); title('سیگنال صوتی اصلی (بخشی از آن)');
subplot(2,1,2);
plot(t(1:1000), stego_audio(1:1000)); title('سیگنال صوتی پنهان‌نگاری شده (Stego)');
