import { v } from "convex/values";
import { mutation, query } from "./_generated/server";
import { Doc } from "./_generated/dataModel";

export const getUser = query({
  args: { userId: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("users")
      .withIndex("by_userId", (q) => q.eq("userId", args.userId))
      .first();
  },
});

export const createUser = mutation({
  args: {
    userId: v.string(),
    username: v.string(),
    profilePicture: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const existingUser = await ctx.db
      .query("users")
      .withIndex("by_userId", (q) => q.eq("userId", args.userId))
      .first();

    if (existingUser) return existingUser;

    return await ctx.db.insert("users", {
      userId: args.userId,
      username: args.username,
      profilePicture: args.profilePicture,
      score: 0,
      gamesPlayed: 0,
      createdAt: Date.now(),
    });
  },
}); 