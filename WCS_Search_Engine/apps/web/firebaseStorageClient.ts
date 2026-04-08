// Firebase Storage client for file uploads
import { getStorage } from 'firebase/storage';
import app from './firebaseClient';

const storage = getStorage(app);
export default storage;
