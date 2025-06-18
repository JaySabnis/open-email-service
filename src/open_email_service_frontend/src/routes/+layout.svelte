<script>
  import Sidebar from "$lib/components/NewSidebar.svelte";
  import { onMount } from "svelte";
  import { theme } from "$lib/store/theme";
  import { colors } from "$lib/store/colors";
  import { goto } from '$app/navigation';
  import { browser } from '$app/environment';
  import { authStore } from "$lib/store/auth-store";
  import "../app.css";
  import { get } from 'svelte/store';
   import { showWriteMail } from '$lib/store/ui';

  let currentTheme;
  let currentColors;
  let authChecked = false;

  const unsubscribeTheme = theme.subscribe(value => {
    currentTheme = value;
    const colorsValue = get(colors);
    currentColors = colorsValue[currentTheme];
    if (typeof window !== "undefined") {
      if (value === 'dark') {
        document.documentElement.classList.add('dark');
      } else {
        document.documentElement.classList.remove('dark');
      }
    }
  });

  function closeWriteMail() {
    showWriteMail = false;
  }

  onMount(async () => {
    if (!browser) return;
    
    try {
      const identity = await authStore.sync();
      if (!identity) await goto('/login');
      authChecked = true;
    } catch (err) {
      console.error("Auth check failed:", err);
      await goto('/login');
    }
  });
</script>


{#if authChecked && $authStore?.identity}
  <div class="flex" style="background-color: {currentColors?.bgLightColor}; color: {currentColors?.color};">
    <Sidebar  />
    <div class="flex-1 ml-64">
      <slot 
        showWriteMail={showWriteMail} 
        closeWriteMail={closeWriteMail} 
      />
    </div>
  </div>
{/if}

<style>
  @tailwind base;
  @tailwind components;
  @tailwind utilities;
</style>