import { writable } from "svelte/store";
import { MailService } from "../services/mail.services";


function mailStore() {
  const { subscribe, set } = writable(undefined);

  async function fetchInboxMails(pageNumber, pageSize) {
    return new MailService().fetchInboxMails(pageNumber,pageSize);
  }

  async function sendEmails(emailData) {
    return new MailService().sendEmails(emailData);
  }

  async function fetchOutboxMails(pageNumberParam = null,pageSizeParam = null) {
    return new MailService().fetchOutboxMails(pageNumberParam,pageSizeParam);
  }

  async function getMailById(mailId) {
    return new MailService().getMailById(mailId);
  }

  async function markItAsImportant(mailId) {
    return new MailService().markItAsImportant(mailId);
  }

  async function markAsNotImportant(mailId) {
    return new MailService().markAsNotImportant(mailId);
  }

  async function fetchStarredMails(pageNumber, pageSize) {
    return new MailService().fetchStarredMails(pageNumber,pageSize);
  }

  async function fetchTrashMails(pageNumber, pageSize) {
    return new MailService().fetchTrashMails(pageNumber,pageSize);
  }

  async function fetchDraftMails(pageNumber, pageSize) {
    return new MailService().fetchDraftMails(pageNumber,pageSize);
  }

  async function saveDraftMail(emailData) {
    return new MailService().saveDraftMail(emailData);
  }

  async function deleteEmail(mailId) {
    return new MailService().deleteEmail(mailId);
  }

  async function restoreEmail(mailId) {
    return new MailService().restoreEmail(mailId);
  }

  async function uploadFile(fileData) {
    return new MailService().uploadFile(fileData);
  }

  async function getFileById(fileId) {
    return new MailService().getFileById(fileId);
  }
  
  async function deleteFile(fileId) {
    return new MailService().deleteFile(fileId);
  }

  async function deleteDraffMail(draftMailId) {
    return new MailService().deleteDraffMail(draftMailId);
  }

  async function sendEditedDraftMails(draftMailId,emailData) {
    return new MailService().sendEditedDraftMails(draftMailId,emailData);
  }

  return {
    fetchInboxMails,
    sendEmails,
    fetchOutboxMails,
    subscribe,
    getMailById,
    markItAsImportant,
    markAsNotImportant,
    fetchStarredMails,
    fetchTrashMails,
    fetchDraftMails,
    saveDraftMail,
    deleteEmail,
    restoreEmail,
    uploadFile,
    getFileById,
    sendEditedDraftMails,
    deleteFile,
    deleteDraffMail
  };
}

export const mailsStore = mailStore();
