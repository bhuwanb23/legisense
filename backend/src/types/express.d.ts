declare namespace Express {
  interface Request {
    user?: {
      id: number;
      email: string;
      fullName: string;
      authProvider: string;
      isActive: boolean;
    };
  }
}
