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

<main class="min-h-screen relative flex items-center justify-center bg-gray-50 dark:bg-gray-900">
  <div class="absolute inset-0 z-0">
    <img
      src="/icp-logo.jpg"
      alt="Background"
      class="w-full h-full object-cover opacity-30 dark:opacity-10"
    />
  </div>

  <div class="relative z-10 w-full max-w-md bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8 md:p-10">
    <h2 class="text-3xl font-bold text-gray-800 dark:text-white mb-4">
      Welcome to Open Email
    </h2>
    <p class="text-gray-600 dark:text-gray-400 mb-6">
      Sign in to access your secure, decentralized inbox.
    </p>

    <button
      on:click={handleLogin}
      class="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 rounded-lg shadow-md transition"
    >
      Login with Internet Identity
    </button>

    <p class="text-xs text-gray-400 mt-6 text-center">
      By continuing, you agree to our
      <a href="/#" class="underline hover:text-blue-600">Terms of Service</a>
      and
      <a href="/#" class="underline hover:text-blue-600">Privacy Policy</a>.
    </p>
  </div>
</main>

