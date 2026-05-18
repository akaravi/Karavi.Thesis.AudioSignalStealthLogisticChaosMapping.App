% evaluate_stego.m
% =========================================================================
% Evaluation Metrics for Audio Steganography
% Environment: MATLAB R2023a
% =========================================================================

function [snr_val, psnr_val, ber_val, npcr_val, uaci_val] = evaluate_stego(x, y, msg_orig, msg_ext, y1, y2, bit_depth)
    % Inputs:
    % x: Original Audio Signal
    % y: Stego Audio Signal
    % msg_orig: Original binary message
    % msg_ext: Extracted binary message
    % y1, y2: Two stego signals with 1-bit difference in key (for NPCR/UACI)
    % bit_depth: e.g., 16 for 16-bit audio
    
    % Ensure signals are column vectors and double precision
    x = double(x(:));
    y = double(y(:));
    N = length(x);
    MAX_I = (2^bit_depth) - 1;

    % ---------------------------------------------------------------------
    % 1. Quality Metrics (SNR & PSNR)
    % ---------------------------------------------------------------------
    signal_power = sum(x.^2);
    noise_power = sum((x - y).^2);
    
    if noise_power == 0
        snr_val = inf;
        psnr_val = inf;
    else
        snr_val = 10 * log10(signal_power / noise_power);
        
        mse = noise_power / N;
        % -- psnr_val = 10 * log10((MAX_I^2) / mse);
        psnr_val = 10 * log10(1.0 / mse); % normalized signal: max amplitude = 1.0
    end

    % ---------------------------------------------------------------------
    % 2. Recovery Accuracy (BER)
    % ---------------------------------------------------------------------
    % Ensure messages are logical arrays
    msg_orig = logical(msg_orig(:));
    msg_ext = logical(msg_ext(:));
    
    M = length(msg_orig);
    errors = sum(msg_orig ~= msg_ext);
    ber_val = (errors / M) * 100; % Returned as percentage

    % ---------------------------------------------------------------------
    % 3. Security Metrics (NPCR & UACI for 1D Audio)
    % ---------------------------------------------------------------------
    y1 = double(y1(:));
    y2 = double(y2(:));
    
    % NPCR
    D = (y1 ~= y2);
    npcr_val = (sum(D) / N) * 100;
    
    % UACI
    uaci_val = (sum(abs(y1 - y2)) / (N * 2.0)) * 100; % normalized signal range = 2 (from -1 to +1)

    % Display Results
    fprintf('--- Evaluation Results ---\n');
    fprintf('SNR  : %.4f dB\n', snr_val);
    fprintf('PSNR : %.4f dB\n', psnr_val);
    fprintf('BER  : %.4f %%\n', ber_val);
    fprintf('NPCR : %.4f %%\n', npcr_val);
    fprintf('UACI : %.4f %%\n', uaci_val);
end
