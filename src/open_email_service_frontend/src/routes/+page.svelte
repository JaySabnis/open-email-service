<script>
  import { signIn } from "$lib/services/auth.service"; 
  import { authStore } from "$lib/store/auth-store";
  import { authSignedInStore } from "$lib/derived/auth.derived"; 
  import { goto } from "$app/navigation"; 
  import { onMount } from "svelte"; 
  import { browser } from "$app/environment"; 
  import { get } from "svelte/store";
  import Login from "$lib/page/login.svelte";
  
  async function handleLogin() {
    // console.log("test click");
    let params = {
      domain: `http://localhost:4943/?canisterId=qhbym-qaaaa-aaaaa-aaafq-cai`,
    };
    await signIn(params);
    goto(`/dashboard`); 
  }

  const init = async () => {
    if (!browser) return;
    await authStore.sync();
  };

  onMount(async () => {
    await init();
    const identity = get(authStore).identity;
    if (identity) {
      goto(`/dashboard`); 
    } else {
      goto('/');
    }
  });
</script>

<svelte:window on:storage={authStore.sync} /> 

<main>
  {#if $authSignedInStore}
    <div>Welcome, you are logged in!</div>
  {:else}
    <!-- <button on:click={handleLogin}>Login test1</button> -->
     <Login/>
  {/if}
</main>

<style>
  /* Add any specific styles for the page here */
</style>
