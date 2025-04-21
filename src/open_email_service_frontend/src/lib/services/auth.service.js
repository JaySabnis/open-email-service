import { authStore } from '../store/auth-store'
import { toasts } from '../store/toast-store'

export const signIn = async (
  params,
) => {
//   busy.show();
  try {
    await authStore.signIn(params);
    return { success: "ok" };
  } catch (err) {
    if (err === "UserInterrupt") {
      return { success: "cancelled" };
    }

    toasts.addToast({
      message: "Error Signing In",
      type: "error",
    });

    return { success: "error", err };
  } finally {
    // busy.stop();
  }
};

export const signOut = () => logout({});

export const initErrorSignOut = async () =>
  await logout({
    msg: {
      message:
        "You have been signed out because there was an error initalizing your profile.",
      type: "error",
    },
  });

export const idleSignOut = async () =>
  await logout({
    msg: {
      message: "You have been logged out because your session has expired.",
      type: "info",
    },
    clearStorages: false,
  });

const logout = async ({
  msg = undefined,
  clearStorages = true,
}) => {
//   busy.start();

  // if (clearStorages) {
  //   await Promise.all([
  //     // DevOps 443: clear storages
  //     console.error("Store clear not implemented"),
  //   ]);
  // }

  console.log("logout")
  await authStore.signOut();

  if (msg) {
    toasts.addToast(msg);
  }

  window.location.reload();
};



