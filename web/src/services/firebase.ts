import { FirebaseError, getApp, getApps, initializeApp } from "firebase/app";
import {
  getAuth,
  onAuthStateChanged,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  GoogleAuthProvider,
  signInWithPopup,
  signOut,
  sendPasswordResetEmail,
  getIdToken,
  ActionCodeSettings,
  User,
} from "firebase/auth";
// import 'firebase/messaging';
// import 'firebase/analytics';
import swal from "sweetalert";

type ErrorMessages = {
  [key: string]: string;
};

!getApps().length
  ? initializeApp({
      apiKey: process.env.VUE_APP_API_KEY,
      authDomain: process.env.VUE_APP_AUTH_DOMAIN,
      databaseURL: process.env.VUE_APP_DATABASE_URL,
      projectId: process.env.VUE_APP_PROJECT_ID,
      storageBucket: process.env.VUE_APP_STORAGE_BUCKET,
      messagingSenderId: process.env.VUE_APP_MESSAGING_SENDER_ID,
      appId: process.env.VUE_APP_APP_ID,
      measurementId: process.env.VUE_APP_MEASUREMENT_ID,
    })
  : getApp();

const auth = getAuth();

function i18n_t(str: string) {
  return str;
}

function alertMessage(err: FirebaseError, title: string) {
  const messages: ErrorMessages = {
    "auth/argument-error": i18n_t("firebaseAuth.errors.argumentError"),
    "auth/invalid-email": i18n_t("firebaseAuth.errors.invalidEmail"),
    "auth/email-already-in-use": i18n_t(
      "firebaseAuth.errors.emailAlreadyInUse"
    ),
  };
  const message = messages[err?.code] || err?.message;
  swal({ title, text: message });
}

export default {
  onAuthStateChanged(callback: (user: User | null) => void) {
    return onAuthStateChanged(auth, (user) => {
      callback(user);
    });
  },
  async signupWithEmailAndPassword(email: string, password: string) {
    try {
      await createUserWithEmailAndPassword(auth, email, password);
    } catch (err) {
      alertMessage(err, i18n_t("firebaseAuth.signup"));
      throw err;
    }
  },
  async loginWithEmailAndPassword(email: string, password: string) {
    try {
      await signInWithEmailAndPassword(auth, email, password);
    } catch (err) {
      alertMessage(err, i18n_t("firebaseAuth.login"));
      throw err;
    }
  },
  async signinWithGoogle() {
    try {
      const provider = new GoogleAuthProvider();
      await signInWithPopup(auth, provider);
    } catch (err) {
      alertMessage(err, i18n_t("firebaseAuth.signin"));
      throw err;
    }
  },
  async signout() {
    try {
      await signOut(auth);
    } catch (err) {
      alertMessage(err, i18n_t("firebaseAuth.signout"));
      throw err;
    }
  },
  async resetPassword(email: string, actionCodeSettings: ActionCodeSettings) {
    try {
      await sendPasswordResetEmail(auth, email, actionCodeSettings);
    } catch (err) {
      alertMessage(err, i18n_t("firebaseAuth.resetPassword"));
      throw err;
    }
  },
  currentUser() {
    return auth.currentUser;
  },
  async getIdToken() {
    const currentUser = this.currentUser();
    return currentUser ? await getIdToken(currentUser) : null;
  },
};
