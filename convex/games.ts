import { v } from "convex/values";
import { mutation, query } from "./_generated/server";
import { Doc } from "./_generated/dataModel";

export const initializeGames = mutation({
  handler: async (ctx) => {
    const existingGames = await ctx.db.query("games").collect();
    if (existingGames.length > 0) return;

    // Initialize Memory Match game
    await ctx.db.insert("games", {
      gameId: "memory_match",
      name: "Memory Match",
      description: "Test your memory by matching pairs of cards. Complete all levels to prove your memory mastery!",
      levels: 10,
      maxScore: 10000,
      isActive: true,
      order: 1,
    });

    // Future games can be added here
  },
});

export const listGames = query({
  handler: async (ctx) => {
    return await ctx.db
      .query("games")
      .withIndex("by_order")
      .filter((q) => q.eq(q.field("isActive"), true))
      .collect();
  },
});

export const getGameProgress = query({
  args: { userId: v.string(), gameId: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("gameProgress")
      .withIndex("by_userId_and_gameId", (q) => 
        q.eq("userId", args.userId).eq("gameId", args.gameId)
      )
      .first();
  },
});

export const updateGameProgress = mutation({
  args: {
    userId: v.string(),
    gameId: v.string(),
    status: v.union(v.literal("not_started"), v.literal("in_progress"), v.literal("completed")),
    currentLevel: v.number(),
    score: v.number(),
    completedAt: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const existing = await ctx.db
      .query("gameProgress")
      .withIndex("by_userId_and_gameId", (q) => 
        q.eq("userId", args.userId).eq("gameId", args.gameId)
      )
      .first();

    if (existing) {
      return await ctx.db.patch(existing._id, {
        status: args.status,
        currentLevel: args.currentLevel,
        score: args.score,
        completedAt: args.completedAt,
      });
    }

    return await ctx.db.insert("gameProgress", {
      ...args,
      startedAt: Date.now(),
    });
  },
}); 