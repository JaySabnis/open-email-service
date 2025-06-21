<script>
  import { onMount } from 'svelte';
  import { authStore } from '$lib/store/auth-store';
  import { profileStore } from '$lib/store/profile-store';
  import { signOut } from '$lib/services/auth.services';
  import { goto } from '$app/navigation';
  import { browser } from '$app/environment';
  import Sidebar from '$lib/components/NewSidebar.svelte';
  import LoginPage from '$lib/components/loginPage.svelte';
  import GlobalLoader from '$lib/components/GlobalLoader.svelte';
  import { showLoader, hideLoader } from '$lib/store/loader-store';
  import '../app.css';

  let identity = null;
  let profile = null;
  let showSidebar = false;
  let showLogin = false;
  let initialized = false;

  async function fetchAndSetProfile() {
    try {
      showLoader('Loading profile...');
      const res = await profileStore.getProfile();
      
      if (res?.err) {
        throw new Error(res.err);
      }

      profile = res?.ok || null;
      showSidebar = !!profile;
      return profile;
    } catch (err) {
      console.error("Profile fetch failed:", err);
      profile = null;
      showSidebar = false;
      return null;
    } finally {
      hideLoader();
    }
  }

  async function initializeApp() {
    if (!browser) return;

    try {
      showLoader('Initializing...');
      identity = await authStore.sync();
      
      if (!identity?.getPrincipal) {
        showLogin = true;
        return;
      }

      const profileExists = await fetchAndSetProfile();
      const currentPath = window.location.pathname;

      if (profileExists) {
        if (currentPath === '/' || currentPath === '/profile') {
          await goto('/home', { replaceState: true });
        }
      } else if (currentPath !== '/profile') {
        await goto('/profile', { replaceState: true });
      }
    } catch (err) {
      console.error("Initialization error:", err);
      showLogin = true;
    } finally {
      initialized = true;
      hideLoader();
    }
  }

  onMount(async () => {
    // signOut();
    await initializeApp();

    const profileUpdateListener = async () => {
      showLoader('Updating profile...');
      await fetchAndSetProfile();
      hideLoader();
    };

    window.addEventListener('profileUpdated', profileUpdateListener);
    
    return () => {
      window.removeEventListener('profileUpdated', profileUpdateListener);
      hideLoader(); 
    };
  });
</script>

{#if !initialized}
  <div class="min-h-screen"></div>
{:else if showLogin}
  <div class="min-h-screen flex items-center justify-center p-4">
    <div class="w-full max-w-md space-y-8">
      <LoginPage />
    </div>
  </div>
{:else}
  <div class="flex">
    {#if showSidebar}
      <Sidebar {profile} />
    {/if}
    <div class="flex-1 {showSidebar ? 'ml-64' : ''}">
      <slot />
    </div>
  </div>
{/if}

<GlobalLoader />

<style>
  @tailwind base;
  @tailwind components;
  @tailwind utilities;
</style>