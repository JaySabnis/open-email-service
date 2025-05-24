<script>
  import { authSignedInStore } from "$lib/derived/auth.derived";
  import Sidebar from "$lib/components/sidebar.svelte";
  import { goto } from "$app/navigation";
  import Navbar from "$lib/components/navbar.svelte";
  import { onMount } from "svelte";
  import { loadUserProfile } from "$lib/store/user";
  import { theme } from "$lib/store/theme";
  import { colors } from "$lib/store/colors";
  import { get } from 'svelte/store';
  import "../app.css";

  let isSidebarOpen = false;
  let isAuthenticated = false;
  let isMobile = false;

  $: isAuthenticated = $authSignedInStore;

  let currentTheme;
  let currentColors;



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
  
  onMount(() => {
    if (!isAuthenticated) {
      goto("/");
    }

    if (window.innerWidth < 768) {
      isMobile = true;
    }
    window.addEventListener("resize", () => {
      isMobile = window.innerWidth < 768;
    });
    loadUserProfile();
  });

  const toggleSidebar = () => {
    isSidebarOpen = !isSidebarOpen;
  };
</script>


<div class="flex min-h-screen" style="
          background-color: {currentColors.bgLightColor};
          color: {currentColors.color};
          border-color: {currentColors.color};
        ">
  {#if isAuthenticated}
    <Sidebar {isSidebarOpen} {toggleSidebar} />
  {/if}

  <div class="flex-1 flex flex-col w-full" style="
          background-color: {currentColors.bgLightColor};
          color: {currentColors.color};
          border-color: {currentColors.color};
        ">
    {#if isAuthenticated}
      <Navbar {currentColors} />
    {/if}

    {#if isAuthenticated}
      <div
        class="w-full border-gray-300 p-2 flex items-center"
        style="
          background-color: {currentColors.surface};
          color: {currentColors.color};
          border-color: {currentColors.color};
        "
      >
       <button
          class="p-2 rounded-md"
          style="background-color: {currentColors.bgLightColor}; color: {currentColors.color};"
          aria-label="Toggle Sidebar"
          on:click={toggleSidebar}
        >
          <svg
            class="w-4 h-4"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            viewBox="0 0 24 24"
          >
            {#if isSidebarOpen}
              <line x1="18" y1="6" x2="6" y2="18" />
              <line x1="6" y1="6" x2="18" y2="18" />
            {:else}
              <line x1="3" y1="12" x2="21" y2="12" />
              <line x1="3" y1="6" x2="21" y2="6" />
              <line x1="3" y1="18" x2="21" y2="18" />
            {/if}
          </svg>
        </button>
        <span class="ml-2 text-sm">
          Menu
        </span>
      </div>
    {/if}

    <main class="flex-1 p-4">
      <slot></slot>
    </main>
  </div>
</div>

<style>
  @reference "tailwindcss";
@tailwind base;
@tailwind components;
@tailwind utilities;

  .layout-container {
    display: flex;
    flex-direction: column;
    min-height: 100vh;
  }

  .content {
    flex: 1;
  }

  .login-prompt {
    text-align: center;
  }
</style>
