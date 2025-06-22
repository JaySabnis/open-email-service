import { ActorFactory } from "../utils/ActorFactory";
import { authStore } from "../store/auth-store";

export class MailService {
  constructor() { }

  async fetchInboxMails(pageNumberParam=null,pageSizeParam=null) {
    const identityActor = await ActorFactory.createIdentityActor(
      authStore,
      "bd3sg-teaaa-aaaaa-qaaba-cai",
    );
    const pageNumber = pageNumberParam || null;
    const pageSize = pageSizeParam || null;
    const result = await identityActor.fetchInboxMails(pageNumber,pageSize);
    return result;
  }

  async sendEmails(emailData){
    const identityActor = await ActorFactory.createIdentityActor(authStore, "bd3sg-teaaa-aaaaa-qaaba-cai");

    let dto = {
      to: emailData.to,
      subject: emailData.subject || null,
      body: emailData.body,
      attachmentIds : emailData.attachmentIds || null,
      isReply: emailData.isReply,
      parentMailId: emailData.parentMailId || null
    };

    const result = await identityActor.sendEmail(dto);
    return result;
  }

  async fetchOutboxMails(pageNumberParam=null,pageSizeParam=null) {
    const identityActor = await ActorFactory.createIdentityActor(
      authStore,
      "bd3sg-teaaa-aaaaa-qaaba-cai",
    );

    const pageNumber = pageNumberParam || null;
    const pageSize = pageSizeParam || null;
    const result = await identityActor.fetchOutboxMails(pageNumber,pageSize);
    return result;
  }

  async getMailById(mailId) {
    const identityActor = await ActorFactory.createIdentityActor(
      authStore,
      "bd3sg-teaaa-aaaaa-qaaba-cai",
    );
    const result = await identityActor.getMailById(mailId);
    return result;
  }

  async markItAsImportant(mailId) {
    console.log(mailId,"mail id received")
    const identityActor = await ActorFactory.createIdentityActor(
      authStore,
      "bd3sg-teaaa-aaaaa-qaaba-cai",
    );
    const result = await identityActor.markItAsImportant(mailId);
    console.log(result,"result here")
    return result;
  }

  async markAsNotImportant(mailId) {
    const identityActor = await ActorFactory.createIdentityActor(
      authStore,
      "bd3sg-teaaa-aaaaa-qaaba-cai",
    );
    const result = await identityActor.markAsNotImportant(mailId);
    return result;
  }
}
