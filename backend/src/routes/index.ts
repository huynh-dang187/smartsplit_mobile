import { Router } from "express";
import authRoutes from "./auth.routes.js";
import groupRoutes from "./group.routes.js";

const apiRouter = Router();

// Mount các tuyến đường Auth & User Profile
apiRouter.use(authRoutes);

// Mount các tuyến đường Group Management
apiRouter.use("/groups", groupRoutes);
apiRouter.use(groupRoutes);

export default apiRouter;
