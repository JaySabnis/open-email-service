import { mailsStore } from "$lib/store/mails-store";
import { profileStore } from '$lib/store/profile-store';
import { authStore } from '$lib/store/auth-store';

export async function getMails(pageType, pageNumber=1, pageSize=10) {
    try {
        const identity = await authStore.sync();
        if (!identity?.getPrincipal) {
            throw new Error("Not authenticated");
        }

        const pageNumberOpt = [pageNumber];
        const pageSizeOpt = [pageSize];

        const currentUserProfile = (await profileStore.getProfile())?.ok || null;

        let mailData;
        switch (pageType) {
            case "sent":
                mailData = await mailsStore.fetchOutboxMails(pageNumberOpt, pageSizeOpt);
                break;
            case "draft":
                mailData = await mailsStore.fetchDraftMails(pageNumberOpt, pageSizeOpt);
                break;
            case "trash":
                mailData = await mailsStore.fetchTrashMails(pageNumberOpt, pageSizeOpt);
                break;
            case "starred":
                mailData = await mailsStore.fetchStarredMails(pageNumberOpt, pageSizeOpt);
                break;
            default:
                mailData = await mailsStore.fetchInboxMails(pageNumberOpt, pageSizeOpt);
        }

        const mails = await Promise.all((mailData?.data || []).map(async (mail) => {
            try {
                let profileData = null;
                
                if (mail?.from) {
                    const fromUserResponse = await profileStore.getProfileByUserAddress(mail.from);
                    profileData = fromUserResponse?.ok || null;
                }
                
                if (!profileData) {
                    profileData = currentUserProfile;
                }

                return {
                    ...mail,
                    profile: profileData
                };
            } catch (err) {
                console.error(`Failed to process mail ${mail?.id}`, err);
                return {
                    ...mail,
                    profile: currentUserProfile 
                };
            }
        }));

        return {
            mails,
            hasNextPage: Number(mailData?.totalPages) > pageNumber,
            error: null
        };
    } catch (err) {
        console.error("Failed to fetch mails:", err);
        return {
            mails: [],
            hasNextPage: false,
            error: err
        };
    }
}