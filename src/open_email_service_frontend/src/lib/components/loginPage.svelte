<script>
  import { signIn } from "$lib/services/auth.services";
  import { goto } from "$app/navigation";
  import { browser } from "$app/environment";

  async function handleLogin() {
    try {
      const params = {
        // domain: `http://localhost:4943/?canisterId=qhbym-qaaaa-aaaaa-aaafq-cai`,
        domain:`https://identity.ic0.app/`
      };
      
      await signIn(params);
      
      await new Promise(resolve => setTimeout(resolve, 500));
      
      if (browser) {
        window.location.href = '/profile';
      }
    } catch (error) {
      console.error("Login failed:", error);
    }
  }
</script>

<main class="min-h-screen relative flex items-center justify-center bg-white">

  <div class="hidden lg:block absolute inset-0">
    <!-- <img src="https://miro.medium.com/v2/resize:fit:1400/1*guz0NRDfCNOU5nnfsiEsFw.jpeg" alt="Login Image" class="w-full h-full" /> -->
  </div>

  <div class="relative z-10 w-full lg:w-1/3 bg-white p-6 rounded-lg shadow-lg text-center">
    <h2 class="text-2xl font-semibold mb-6">Welcome to Our Platform</h2>
    <p class="text-gray-600 mb-6">Please login to continue</p>
    <button
      on:click={handleLogin}
      class="w-full bg-blue-500 text-white py-3 px-6 rounded-lg hover:bg-blue-600 transition duration-200"
    >
      Login with Internet Identity
    </button>
  </div>

</main>

<style>
</style>
