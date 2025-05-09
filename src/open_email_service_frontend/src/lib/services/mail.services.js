import { ActorFactory } from "../utils/ActorFactory";
import { authStore } from "../store/auth-store";

export class MailService {
  constructor() { }

  async fetchInboxMails() {
    const identityActor = await ActorFactory.createIdentityActor(
      authStore,
      "bd3sg-teaaa-aaaaa-qaaba-cai",
    );
    const result = await identityActor.fetchInboxMails();
    return result;
  }

  async sendEmails(emailData){
    const identityActor = await ActorFactory.createIdentityActor(authStore, "bd3sg-teaaa-aaaaa-qaaba-cai");

    let dto = {
      to: emailData.to,
      subject: emailData.subject,
      body: emailData.body
    };

    const result = await identityActor.sendEmail(dto);
    return result;
  }

  async fetchOutboxMails() {
    const identityActor = await ActorFactory.createIdentityActor(
      authStore,
      "bd3sg-teaaa-aaaaa-qaaba-cai",
    );
    const result = await identityActor.fetchOutboxMails();
    return result;
  }

}
