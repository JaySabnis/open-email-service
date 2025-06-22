import { createAuthClient } from "../utils/auth.utils";
import { AuthClient } from "@dfinity/auth-client";
import { writable } from "svelte/store";
import { AUTH_MAX_TIME_TO_LIVE } from '../constants/app.constants';
import { browser } from '$app/environment';

let authClient;

const NNS_IC_ORG_ALTERNATIVE_ORIGIN = "https://5p73d-fiaaa-aaaaa-qauwa-cai.icp0.io";
const NNS_IC_APP_DERIVATION_ORIGIN =
  "https://5p73d-fiaaa-aaaaa-qauwa-cai.icp0.io";

const isNnsAlternativeOrigin = () => {
  return window.location.origin === NNS_IC_ORG_ALTERNATIVE_ORIGIN;
};

const initAuthStore = () => {
    const initialValue = browser 
        ? JSON.parse(localStorage.getItem('auth')) || { identity: undefined }
        : { identity: undefined };

    const { subscribe, set, update } = writable(initialValue);

    if (browser) {
        subscribe(($auth) => {
            localStorage.setItem('auth', JSON.stringify($auth));
        });
    }

    return {
        subscribe,

        sync: async () => {
            authClient = authClient ?? (await createAuthClient());
            const isAuthenticated = await authClient.isAuthenticated();
            const identity = isAuthenticated ? authClient.getIdentity() : null;
            
            set({ identity });
            return identity;
        },

        signIn: ({ domain = "https://5p73d-fiaaa-aaaaa-qauwa-cai.icp0.io" }) =>
            new Promise(async (resolve, reject) => {
                try {
                    authClient = authClient ?? (await createAuthClient());
                    const identityProvider = domain;

                    await authClient.login({
                        maxTimeToLive: AUTH_MAX_TIME_TO_LIVE,
                        onSuccess: () => {
                            const identity = authClient.getIdentity();
                            set({ identity });
                            resolve(identity);
                        },
                        onError: (err) => {
                            console.error("Login failed:", err);
                            reject(err);
                        },
                        identityProvider,
                         ...(isNnsAlternativeOrigin() && {
                                derivationOrigin: NNS_IC_APP_DERIVATION_ORIGIN,
                            })
                    });
                } catch (err) {
                    console.error("Login error:", err);
                    reject(err);
                }
            }),

        signOut: async () => {
            try {
                const client = authClient ?? (await createAuthClient());
                await client.logout();
                authClient = null;
                set({ identity: null });
                localStorage.removeItem("userProfileCache");
                localStorage.removeItem("auth");
            } catch (err) {
                console.error("Logout error:", err);
            }
        },
    };
};

export const authStore = initAuthStore();