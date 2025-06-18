<script>
  import { authStore } from "$lib/store/auth-store";
  import { goto } from "$app/navigation";
  import { onMount } from "svelte";
  import { browser } from "$app/environment";
  import LoginPage from "$lib/components/loginPage.svelte";

  let showLogin = false;
  let error = null;

  onMount(async () => {
    if (!browser) return;
    
    try {
      const identity = await authStore.sync();
      
      if (identity) {
        await goto('/');
        return;
      }
      
      showLogin = true;
    } catch (err) {
      console.error("Auth check failed:", err);
      error = "Failed to check authentication status";
      showLogin = true;
    }
  });
</script>

{#if showLogin}
  <div class="min-h-screen flex items-center justify-center bg-gray-50 p-4">
    <div class="w-full max-w-md space-y-8">
      {#if error}
        <div class="text-red-500 p-4 bg-red-50 rounded-md">{error}</div>
      {/if}
      
     <LoginPage/>
    </div>
  </div>
{:else}
  <div class="fixed inset-0 flex items-center justify-center">
    <div class="text-lg">Checking authentication...</div>
  </div>
{/if}