<script>
  import { authSignedInStore } from "$lib/derived/auth.derived"; 
  import { goto } from "$app/navigation";
  import Navbar from "$lib/components/navbar.svelte"; 
  import { onMount } from "svelte";
  import "../app.css";
  
  let isAuthenticated = false;

  $: isAuthenticated = $authSignedInStore;

  onMount(() => {
    if (!isAuthenticated) {
      goto('/');
    }
  });
</script>

<div class="layout-container">
  {#if isAuthenticated}
    <Navbar /> 
  {/if}
  
  <main class="content">
    <slot></slot> 
  </main>

  {#if !isAuthenticated}
    <div class="login-prompt">
      <!-- <button on:click={() => goto('/')}>Login test</button>  -->
    </div>
  {/if}
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
