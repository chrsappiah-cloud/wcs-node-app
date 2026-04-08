import { getFirestore } from 'firebase/firestore';
import app from './firebaseClient';

const db = getFirestore(app);
export default db;
