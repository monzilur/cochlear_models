function [b,a]=gammatone(cf,bw,fs)
  phi=2*pi*bw'/fs;
  theta=2*pi*cf'/fs;
  alpha=-exp(-phi).*cos(theta);
  
  a=ones(numel(cf),3);
  a(:,2)=2*alpha;
  a(:,3)=exp(-2*phi);
  
  z1=(1+alpha.*cos(theta))-1i*(alpha.*sin(theta));
  z2=(1+a(:,2).*cos(theta))-1i*(a(:,2).*sin(theta));
  z3=(a(:,3).*cos(2*theta))-1i*(a(:,3).*sin(2*theta));
  
  b=ones(numel(cf),2);
  b(:,1)=abs((z2+z3)./z1);
  b(:,2)=alpha.*b(:,1);
end