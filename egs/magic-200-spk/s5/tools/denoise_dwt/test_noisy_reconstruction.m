[noise, fs_noise] = audioread('./noise/street.wav');
[clean, fs_clean] = audioread('./clean/SA1.WAV');
file = './noisy/SA1_street_10_mine.WAV';
file_rec = './reconstructed/SA1_street_snr_10_wden-s-sln-sub.WAV';
[x, Fs] = audioread(file);
L = 5;
wav_name = 'db8';

% DWT
ignore_level=30;
rec_with = 'd'; % 'd' for reconstructing with details only, 'cd' using both coarse and details
%x_rec = reconstruct_wavelet(x, L, wav_name, ignore_level, rec_with);

% Threshold
x_rec = wden(x, 'sqtwolog', 's', 'sln', 5, 'db8');



% Substract
x_rec = x-x_rec(1:numel(x)); 

audiowrite(file_rec, x_rec, Fs);

if numel(x_rec) ~= numel(clean)
    x_rec = x_rec(1:numel(clean));
end
    
rec_noise = clean - x_rec;
snr_rec = snr(x_rec, rec_noise)