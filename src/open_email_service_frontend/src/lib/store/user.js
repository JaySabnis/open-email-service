import { writable } from 'svelte/store';
import { profileStore } from "$lib/store/profile-store";
// import { pageLoading } from '$lib/store/loading';

const EXPIRY_TIME_MS = 1000 * 60 * 60 * 24 * 2; 
const CACHE_KEY = 'userProfileCache';

function isStale(timestamp) {
    return !timestamp || Date.now() - timestamp > EXPIRY_TIME_MS;
}

export const userProfile = writable(null);

export async function loadUserProfile(forceRefresh = false) {
    try {
        // pageLoading.set(true);
        const cached = JSON.parse(localStorage.getItem(CACHE_KEY));

        if (!forceRefresh && cached?.data && !isStale(cached.timestamp)) {
            userProfile.set(cached.data);
            // pageLoading.set(false);

            // Background refresh
            profileStore.getProfile().then(async (res) => {
                const profile = res.ok || null;
                if (profile) {
                    const cleanedProfile = await extractProfileData(profile);
                    userProfile.set(cleanedProfile);
                    localStorage.setItem(CACHE_KEY, JSON.stringify({
                        data: cleanedProfile,
                        timestamp: Date.now()
                    }));
                }
            }).catch(err => {
                console.error("Background profile fetch failed:", err);
            });

            return;
        }

        const response = await profileStore.getProfile();
        const profile = response.ok || null;

        if (profile) {
            const cleanedProfile = await extractProfileData(profile);
            userProfile.set(cleanedProfile);

            localStorage.setItem(CACHE_KEY, JSON.stringify({
                data: cleanedProfile,
                timestamp: Date.now()
            }));
        } else {
            userProfile.set(null);
            localStorage.removeItem(CACHE_KEY);
        }
    } catch (err) {
        console.error('Error loading profile:', err);
        userProfile.set(null);
    } finally {
        // pageLoading.set(false);
    }
}

export function clearUserProfile() {
    userProfile.set(null);
    localStorage.removeItem(CACHE_KEY);
}

async function extractProfileData(profile) {
    const image = profile.profileImage?.[0];
    let profileImageBase64 = '';
    if (image) {
        const byteArray = new Uint8Array(profile.profileImage[0]);
        const blob = new Blob([byteArray], { type: 'image/jpeg' });

        profileImageBase64 = await blobToBase64(blob);
    }

    // console.log(profileImageBase64,"profileImageBase64");

    return {
        name: profile.name || '',
        surname: profile.surname || '',
        userAddress: profile.userAddress || '',
        status: profile.status?.[0] || '',
        description: profile.description?.[0] || '',
        profileImage: profileImageBase64 
    };
}

function blobToBase64(blob) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onloadend = () => resolve(reader.result);
        reader.onerror = reject;
        reader.readAsDataURL(blob); 
    });
}