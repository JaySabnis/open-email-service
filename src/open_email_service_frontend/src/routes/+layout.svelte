<script>
  import { onMount } from 'svelte';
  import { authStore } from '$lib/store/auth-store';
  import { profileStore } from '$lib/store/profile-store';
  import { goto } from '$app/navigation';
  import { browser } from '$app/environment';
  import Sidebar from '$lib/components/NewSidebar.svelte';
  import Loader from '$lib/components/loader.svelte';
  import "../app.css";

  let identity = null;
  let profile = null;
  let showSidebar = false;
  let loading = true;

  async function fetchAndSetProfile() {
    try {
      const res = await profileStore.getProfile();
      profile = res.ok || null;
      showSidebar = !!profile;
    } catch (err) {
      console.error("Profile fetch failed:", err);
      profile = null;
      showSidebar = false;
    }
  }

  onMount(async () => {
    if (!browser) return;

    const currentPath = window.location.pathname;
    identity = await authStore.sync();

    if (!identity && currentPath !== '/login') {
      goto('/login');
      return;
    }

    if (identity) {
      await fetchAndSetProfile();

      if (currentPath === '/login') {
        if (profile) {
          goto('/');
        } else {
          goto('/profile');
        }
        return;
      }

      if (!profile && currentPath !== '/profile') {
        goto('/profile');
        return;
      }
    }

    loading = false;

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
{:else}
  <div class="flex">
    {#if showSidebar}
      <Sidebar />
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