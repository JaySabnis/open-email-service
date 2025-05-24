export const idlFactory = ({ IDL }) => {
  const CreateProfileDTO = IDL.Record({
    'status' : IDL.Opt(IDL.Text),
    'profileImage' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'name' : IDL.Text,
    'description' : IDL.Opt(IDL.Text),
    'surname' : IDL.Text,
    'userAddress' : IDL.Text,
  });
  const ProfileError = IDL.Variant({
    'NotFound' : IDL.Null,
    'InvalidData' : IDL.Text,
    'AlreadyExists' : IDL.Text,
    'AnonymousCaller' : IDL.Null,
  });
  const ProfileResult = IDL.Variant({ 'ok' : IDL.Null, 'err' : ProfileError });
  const Timestamp__1 = IDL.Int;
  const EmailResponseDTO = IDL.Record({
    'id' : IDL.Text,
    'to' : IDL.Text,
    'subject' : IDL.Text,
    'starred' : IDL.Bool,
    'from' : IDL.Text,
    'createdOn' : Timestamp__1,
    'readFlag' : IDL.Bool,
  });
  const File = IDL.Record({
    'contentType' : IDL.Text,
    'size' : IDL.Nat,
    'fileName' : IDL.Text,
    'filedata' : IDL.Vec(IDL.Nat8),
    'fileId' : IDL.Text,
  });
  const FileErrors = IDL.Variant({
    'NotFound' : IDL.Null,
    'UnexpectedErrorOccured' : IDL.Null,
  });
  const Result_4 = IDL.Variant({ 'ok' : File, 'err' : FileErrors });
  const FileResponseDTO = IDL.Record({
    'size' : IDL.Nat,
    'fileName' : IDL.Text,
    'fileId' : IDL.Text,
  });
  const EmailBodyResponseDTO = IDL.Record({
    'id' : IDL.Text,
    'to' : IDL.Text,
    'subject' : IDL.Text,
    'starred' : IDL.Bool,
    'body' : IDL.Text,
    'from' : IDL.Text,
    'createdOn' : Timestamp__1,
    'readFlag' : IDL.Bool,
    'attachments' : IDL.Opt(IDL.Vec(FileResponseDTO)),
  });
  const EmailErrors = IDL.Variant({
    'InvalidRecipientAddress' : IDL.Null,
    'NotFound' : IDL.Null,
    'ErrorSelfTransfer' : IDL.Null,
    'AnonymousCaller' : IDL.Null,
  });
  const Result_3 = IDL.Variant({
    'ok' : IDL.Vec(EmailBodyResponseDTO),
    'err' : EmailErrors,
  });
  const Timestamp = IDL.Int;
  const Profile = IDL.Record({
    'id' : IDL.Principal,
    'status' : IDL.Opt(IDL.Text),
    'modifiedOn' : Timestamp,
    'profileImage' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'name' : IDL.Text,
    'createdOn' : Timestamp,
    'description' : IDL.Opt(IDL.Text),
    'surname' : IDL.Text,
    'userAddress' : IDL.Text,
  });
  const Result_1 = IDL.Variant({ 'ok' : Profile, 'err' : ProfileError });
  const Thread = IDL.Record({
    'headMailId' : IDL.Text,
    'replyMailIds' : IDL.Vec(IDL.Text),
    'isNewMailAdded' : IDL.Bool,
  });
  const SendEmailDTO = IDL.Record({
    'to' : IDL.Text,
    'attachmentIds' : IDL.Vec(IDL.Text),
    'subject' : IDL.Text,
    'body' : IDL.Text,
    'isReply' : IDL.Bool,
    'parentMailId' : IDL.Opt(IDL.Text),
  });
  const Email = IDL.Record({
    'to' : IDL.Text,
    'attachmentIds' : IDL.Vec(IDL.Text),
    'subject' : IDL.Text,
    'body' : IDL.Text,
    'from' : IDL.Text,
    'createdOn' : Timestamp__1,
    'isReply' : IDL.Bool,
    'parentMailId' : IDL.Opt(IDL.Text),
  });
  const Result_2 = IDL.Variant({ 'ok' : Email, 'err' : EmailErrors });
  const UpdateProfileDTO = IDL.Record({
    'status' : IDL.Opt(IDL.Text),
    'profileImage' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'name' : IDL.Opt(IDL.Text),
    'description' : IDL.Opt(IDL.Text),
    'surname' : IDL.Opt(IDL.Text),
  });
  const FileRequestDTO = IDL.Record({
    'contentType' : IDL.Text,
    'fileName' : IDL.Text,
    'filedata' : IDL.Vec(IDL.Nat8),
  });
  const Result = IDL.Variant({ 'ok' : FileResponseDTO, 'err' : FileErrors });
  return IDL.Service({
    'createProfile' : IDL.Func([CreateProfileDTO], [ProfileResult], []),
    'deleteProfile' : IDL.Func([], [ProfileResult], []),
    'fetchInboxMails' : IDL.Func(
        [IDL.Opt(IDL.Nat), IDL.Opt(IDL.Nat)],
        [IDL.Vec(EmailResponseDTO)],
        [],
      ),
    'fetchOutboxMails' : IDL.Func(
        [IDL.Opt(IDL.Nat), IDL.Opt(IDL.Nat)],
        [IDL.Vec(EmailResponseDTO)],
        [],
      ),
    'getFile' : IDL.Func([IDL.Text], [Result_4], ['query']),
    'getMailById' : IDL.Func([IDL.Text], [Result_3], []),
    'getProfile' : IDL.Func([], [Result_1], []),
    'getThreads' : IDL.Func([IDL.Text], [IDL.Opt(Thread)], ['query']),
    'isUserAddressAvailable' : IDL.Func([IDL.Text], [IDL.Bool], ['query']),
    'markItAsImportant' : IDL.Func([IDL.Text], [], []),
    'sendEmail' : IDL.Func([SendEmailDTO], [Result_2], []),
    'updateProfile' : IDL.Func([UpdateProfileDTO], [Result_1], []),
    'uploadFile' : IDL.Func([FileRequestDTO], [Result], []),
  });
};
export const init = ({ IDL }) => { return []; };
