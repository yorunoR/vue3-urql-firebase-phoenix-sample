// external lib
import PrimeVue from "primevue/config";
// vue
import { createApp } from "vue";
import App from "./App.vue";
import "./registerServiceWorker";
import router from "./router";
import store from "./store";
// css
import "primevue/resources/themes/saga-blue/theme.css";
import "primevue/resources/primevue.css";
import "primeicons/primeicons.css";
// primevue components
import Button from "primevue/button";

createApp(App)
  .use(store)
  .use(router)
  .use(PrimeVue)
  .component("Button", Button)
  .mount("#app");
