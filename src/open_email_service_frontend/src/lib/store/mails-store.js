import { writable } from "svelte/store";
import { MailService } from "../services/mail.services";


function mailStore() {
  const { subscribe, set } = writable(undefined);

  async function fetchInboxMails() {
    return new MailService().fetchInboxMails();
  }

  async function sendEmails(emailData) {
    return new MailService().sendEmails(emailData);
  }

  async function fetchOutboxMails() {
    return new MailService().fetchOutboxMails();
  }

  return {
    fetchInboxMails,
    sendEmails,
    fetchOutboxMails,
    subscribe,
  };
}

export const mailsStore = mailStore();
