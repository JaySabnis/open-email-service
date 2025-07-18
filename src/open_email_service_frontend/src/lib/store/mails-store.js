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

  return {
    fetchInboxMails,
    sendEmails,
    fetchOutboxMails,
    subscribe,
    getMailById,
    markItAsImportant,
    markAsNotImportant
  };
}

export const mailsStore = mailStore();
