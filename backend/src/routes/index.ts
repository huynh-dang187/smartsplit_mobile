import { Router } from "express";
import authRoutes from "./auth.routes.js";

const apiRouter = Router();

// Mount các tuyến đường Auth & User Profile
apiRouter.use(authRoutes);

export default apiRouter;
