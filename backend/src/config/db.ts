import mongoose from "mongoose";
import dotenv from "dotenv";

dotenv.config();

const MONGODB_URI = process.env.MONGODB_URI || "mongodb://localhost:27017/smartsplit";

export const connectDB = async (): Promise<typeof mongoose> => {
  try {
    const conn = await mongoose.connect(MONGODB_URI);
    console.log(`[MongoDB] Connected successfully to host: ${conn.connection.host}, database: ${conn.connection.name}`);
    return conn;
  } catch (error) {
    console.error("[MongoDB] Connection error:", error);
    process.exit(1);
  }
};

export const disconnectDB = async (): Promise<void> => {
  try {
    await mongoose.disconnect();
    console.log("[MongoDB] Disconnected successfully");
  } catch (error) {
    console.error("[MongoDB] Disconnect error:", error);
  }
};

export default connectDB;
