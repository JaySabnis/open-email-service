<script>
    import { authSignedInStore } from "$lib/derived/auth.derived";
  import Sidebar from '$lib/components/sidebar.svelte';
  import { goto } from "$app/navigation";
  import Navbar from "$lib/components/navbar.svelte"; 
  import { onMount } from "svelte";
  import "../app.css";

  let isSidebarOpen = false;
  let isAuthenticated = false; 
  let isMobile = false;

  $: isAuthenticated = $authSignedInStore;

  onMount(() => {
    if (!isAuthenticated) {
      goto('/');
    }

    if (window.innerWidth < 768) {
      isMobile = true;
    }
    window.addEventListener('resize', () => {
      isMobile = window.innerWidth < 768;
    });
  });

  const toggleSidebar = () => {
    isSidebarOpen = !isSidebarOpen;
  };
</script>

<div class="layout-container">
  {#if isAuthenticated}
    <Sidebar {isSidebarOpen} {toggleSidebar} />
  {/if}

  <div
    class=""
    class:ml-64={isAuthenticated && isSidebarOpen} 
    class:ml-16={isAuthenticated && !isSidebarOpen}
  >
    {#if isAuthenticated}
      <Navbar />
    {/if}

    <main class="content">
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
    /* padding: 20px; */
  }

  .login-prompt {
    /* padding: 20px; */
    text-align: center;
  }
</style>
