<script>
  import { authSignedInStore } from "$lib/derived/auth.derived";
  import Sidebar from "$lib/components/sidebar.svelte";
  import { goto } from "$app/navigation";
  import Navbar from "$lib/components/navbar.svelte";
  import { onMount } from "svelte";
  import { loadUserProfile } from "$lib/store/user";

  import "../app.css";

  let isSidebarOpen = false;
  let isAuthenticated = false;
  let isMobile = false;

  $: isAuthenticated = $authSignedInStore;

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

<div class="flex min-h-screen">
  {#if isAuthenticated}
    <Sidebar {isSidebarOpen} {toggleSidebar} />
  {/if}

  <div class="flex-1 flex flex-col w-full">
    {#if isAuthenticated}
      <Navbar />
    {/if}

    {#if isAuthenticated}
      <div
        class="w-full bg-gray-100  border-gray-300 p-2 flex items-center"
      >
        <button
          class="p-2 bg-gray-200 rounded-md"
          aria-label="Toggle Sidebar"
          on:click={toggleSidebar}
        >
          <svg
            class="w-4 h-4 text-gray-700"
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
        <span class="ml-2 text-sm text-gray-700">Menu</span>
      </div>
    {/if}

    <main class="flex-1 p-4">
      <slot></slot>
    </main>
  </div>
</div>

<style>
  @reference "tailwindcss";
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
