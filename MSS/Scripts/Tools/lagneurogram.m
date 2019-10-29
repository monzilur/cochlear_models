function y=lagneurogram(x,maxshift)
  % Create shifted versions of each row
  y=cellfun(@(z) lagPSTH(z,maxshift),num2cell(x,2),'uni',0);
  
  % Combine rows to create lagged vectors
  y=cat(2,y{:});
end