function rec_signal=reconstruct_wavelet(x,L,wav_name, ignore_level,rec_with);
%[C, L] = wavedec(x, L, wav_name);
%rec_signal = waverec(C,L,wav_name);
approx= x;
detailSave=cell(L,1);
ignore_detail=ignore_level;
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
      if i>ignore_detail
          dets=zeros(numel(dets),1);
      end      
      y_approx=idwt(y_approx,dets,'db8');
end
rec_signal = y_approx;
end