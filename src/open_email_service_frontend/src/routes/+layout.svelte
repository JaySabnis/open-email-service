<script>
  import { onMount } from 'svelte';
  import { authStore } from '$lib/store/auth-store';
  import { profileStore } from '$lib/store/profile-store';
  import { signOut } from '$lib/services/auth.services';
  import { goto } from '$app/navigation';
  import { browser } from '$app/environment';
  import Sidebar from '$lib/components/NewSidebar.svelte';
  import Loader from '$lib/components/loader.svelte';
  import LoginPage from '$lib/components/loginPage.svelte';
  import '../app.css';

  let identity = null;
  let profile = null;
  let showSidebar = false;
  let loading = true;
  let showLogin = false;
  let authInitialized = false;

  async function fetchAndSetProfile() {
    try {
      if (!identity || !identity.getPrincipal) {
        console.error("Invalid identity state");
        return;
      }

      const res = await profileStore.getProfile();
      profile = res?.ok || null;
      showSidebar = !!profile;
      return profile; 
    } catch (err) {
      console.error("Profile fetch failed:", err);
      profile = null;
      showSidebar = false;
      return null;
    }
  }

  onMount(async () => {
    // await signOut()
    if (!browser) return;

    try {
      identity = await authStore.sync();
      authInitialized = true;
      
      if (!identity) {
        showLogin = true;
        loading = false;
        return;
      }

      const profileExists = await fetchAndSetProfile();

      const currentPath = window.location.pathname;
      
      if (profileExists) {
        if (currentPath === '/' || currentPath === '/profile') {
          await goto('/home', { replaceState: true });
        }
      } else {
        if (currentPath !== '/profile') {
          await goto('/profile', { replaceState: true });
        }
      }
    } catch (err) {
      console.error("Initialization error:", err);
    } finally {
      loading = false;
    }

    const listener = async () => {
      loading = true;
      await fetchAndSetProfile();
      loading = false;
    };
    window.addEventListener('profileUpdated', listener);

    return () => window.removeEventListener('profileUpdated', listener);
  });
</script>

{#if loading}
  <Loader message="Loading your experience..." />
{:else if showLogin}
  <div class="min-h-screen flex items-center justify-center bg-gray-50 p-4">
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

<style>
  @tailwind base;
  @tailwind components;
  @tailwind utilities;
</style>
