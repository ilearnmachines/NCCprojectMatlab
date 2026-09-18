function [Reg ] = GetRegMatrix( info )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
Reg = [];
RegSequence = info.RegistrationSequence;
F = fields(RegSequence);
S= size(F);
for n=1:S(1)
    Seq = RegSequence.(F{n});
   % RegType = Seq.MatrixRegistrationSequence.Item_1.RegistrationTypeCodeSequence.Item_1.CodeMeaning;
   % if ~strcmp(RegType,'Frame of Reference Identity')
        Reg = Seq.MatrixRegistrationSequence.Item_1.MatrixSequence.Item_1.FrameOfReferenceTransformationMatrix;
   % end
  Reg = reshape(Reg,4,4);
Reg = Reg';
RegS{n} = Reg;  
end

Reg = RegS{2}*RegS{1};
end

