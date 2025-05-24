import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface CreateProfileDTO {
  'status' : [] | [string],
  'profileImage' : [] | [Uint8Array | number[]],
  'name' : string,
  'description' : [] | [string],
  'surname' : string,
  'userAddress' : string,
}
export interface Email {
  'to' : string,
  'attachmentIds' : Array<string>,
  'subject' : string,
  'body' : string,
  'from' : string,
  'createdOn' : Timestamp__1,
  'isReply' : boolean,
  'parentMailId' : [] | [string],
}
export interface EmailBodyResponseDTO {
  'id' : string,
  'to' : string,
  'subject' : string,
  'starred' : boolean,
  'body' : string,
  'from' : string,
  'createdOn' : Timestamp__1,
  'readFlag' : boolean,
  'attachments' : [] | [Array<FileResponseDTO>],
}
export type EmailErrors = { 'InvalidRecipientAddress' : null } |
  { 'NotFound' : null } |
  { 'ErrorSelfTransfer' : null } |
  { 'AnonymousCaller' : null };
export interface EmailResponseDTO {
  'id' : string,
  'to' : string,
  'subject' : string,
  'starred' : boolean,
  'from' : string,
  'createdOn' : Timestamp__1,
  'readFlag' : boolean,
}
export interface File {
  'contentType' : string,
  'size' : bigint,
  'fileName' : string,
  'filedata' : Uint8Array | number[],
  'fileId' : string,
}
export type FileErrors = { 'NotFound' : null } |
  { 'UnexpectedErrorOccured' : null };
export interface FileRequestDTO {
  'contentType' : string,
  'fileName' : string,
  'filedata' : Uint8Array | number[],
}
export interface FileResponseDTO {
  'size' : bigint,
  'fileName' : string,
  'fileId' : string,
}
export interface Profile {
  'id' : Principal,
  'status' : [] | [string],
  'modifiedOn' : Timestamp,
  'profileImage' : [] | [Uint8Array | number[]],
  'name' : string,
  'createdOn' : Timestamp,
  'description' : [] | [string],
  'surname' : string,
  'userAddress' : string,
}
export type ProfileError = { 'NotFound' : null } |
  { 'InvalidData' : string } |
  { 'AlreadyExists' : string } |
  { 'AnonymousCaller' : null };
export type ProfileResult = { 'ok' : null } |
  { 'err' : ProfileError };
export type Result = { 'ok' : FileResponseDTO } |
  { 'err' : FileErrors };
export type Result_1 = { 'ok' : Profile } |
  { 'err' : ProfileError };
export type Result_2 = { 'ok' : Email } |
  { 'err' : EmailErrors };
export type Result_3 = { 'ok' : Array<EmailBodyResponseDTO> } |
  { 'err' : EmailErrors };
export type Result_4 = { 'ok' : File } |
  { 'err' : FileErrors };
export interface SendEmailDTO {
  'to' : string,
  'attachmentIds' : Array<string>,
  'subject' : string,
  'body' : string,
  'isReply' : boolean,
  'parentMailId' : [] | [string],
}
export interface Thread {
  'headMailId' : string,
  'replyMailIds' : Array<string>,
  'isNewMailAdded' : boolean,
}
export type Timestamp = bigint;
export type Timestamp__1 = bigint;
export interface UpdateProfileDTO {
  'status' : [] | [string],
  'profileImage' : [] | [Uint8Array | number[]],
  'name' : [] | [string],
  'description' : [] | [string],
  'surname' : [] | [string],
}
export interface _SERVICE {
  'createProfile' : ActorMethod<[CreateProfileDTO], ProfileResult>,
  'deleteProfile' : ActorMethod<[], ProfileResult>,
  'fetchInboxMails' : ActorMethod<
    [[] | [bigint], [] | [bigint]],
    Array<EmailResponseDTO>
  >,
  'fetchOutboxMails' : ActorMethod<
    [[] | [bigint], [] | [bigint]],
    Array<EmailResponseDTO>
  >,
  'getFile' : ActorMethod<[string], Result_4>,
  'getMailById' : ActorMethod<[string], Result_3>,
  'getProfile' : ActorMethod<[], Result_1>,
  'getThreads' : ActorMethod<[string], [] | [Thread]>,
  'isUserAddressAvailable' : ActorMethod<[string], boolean>,
  'markItAsImportant' : ActorMethod<[string], undefined>,
  'sendEmail' : ActorMethod<[SendEmailDTO], Result_2>,
  'updateProfile' : ActorMethod<[UpdateProfileDTO], Result_1>,
  'uploadFile' : ActorMethod<[FileRequestDTO], Result>,
}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
