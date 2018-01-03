function reconstruct_wavelet(clean_file, nfile, dnfile, L , wav_name, ignore_level, rec_with, sub, utt_id);
% cleanfile: original timit audio without noise. To compute SNR
% nfile: input noise-effected audio
% dnfile: denoised output audio
% L: DWT level
% wav_name: Wavelet name. E.g., 'db8'
% ignore_level: detail level above this number will be ignored
% rec_with: 'cd', reconstruct with both coarse and detail;
%            'd', reconstructed with details only;
% sub: If 'yes', sig_rcstrcted = sig_noised -sig_rcstcted
maxNumCompThreads(1);
[clean, Fs_clean] = audioread(clean_file);
[x, Fs] = audioread(nfile);
approx= x;
detailSave=cell(L,1);

for i=1:L;
    [approx, details] = dwt(approx, wav_name);
    detailSave{i}=details;
end
if strcmp(rec_with, 'cd');
    y_approx = approx;
elseif strcmp(rec_with, 'd');
    y_approx = zeros(numel(approx),1);
end
for i=L:-1:1
      if numel(y_approx)~=numel(detailSave{i})
          y_approx=y_approx(1:numel(detailSave{i}));
      end
      dets=detailSave{i};
      if i>ignore_level
          dets=zeros(numel(dets),1);
      end
      y_approx=idwt(y_approx,dets,wav_name);
end
x_rec = y_approx;

if strcmp(sub, 'yes');
    x_rec = x - x_rec(1:numel(x));
end

audiowrite(dnfile, x_rec, Fs);

%%%%%%%%%%%%%%% Compute SNR %%%%%%%%%%%%%%%%%%%%%
if numel(x_rec) ~= numel(clean);
    x_rec = x_rec(1:numel(clean));
end
rec_noise = clean - x_rec;
snr_rec = snr(x_rec, rec_noise);
fprintf('%s reconstructed SNR is %f\n', utt_id, snr_rec);
end
