'use client'
import { useEffect, useState, useCallback } from "react";

export interface Coin {
  id: string;
  name: string;
  symbol: string;
  image: string;
  price: number;
  priceFormatted: string;
  change24h: number;
  changeFormatted: string;
  decimals: number;
}

export function useCoins() {
  const [coins, setCoins] = useState<Coin[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchCoins() {
      try {
        const res = await fetch("https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=50&page=1&sparkline=false");
        const data = await res.json();

        if (!Array.isArray(data)) {
          throw new Error("Invalid response from CoinGecko");
        }

        const formattedData = data.map((coin: any) => ({
          id: coin.id,
          name: coin.name,
          symbol: coin.symbol.toUpperCase(),
          image: coin.image,
          price: coin.current_price,
          priceFormatted: coin.current_price != null ? `$${coin.current_price.toLocaleString()}` : "—",
          change24h: coin.price_change_percentage_24h,
          changeFormatted: coin.price_change_percentage_24h != null ? `${coin.price_change_percentage_24h.toFixed(2)}%` : "0.00%",
          decimals: 18, // Defaulting to 18 for most assets
        }));
        
        setCoins(formattedData);
      } catch (error) {
        console.error("CoinGecko fetch error:", error);
      } finally {
        setLoading(false);
      }
    }

    fetchCoins();
  }, []);

  const getCoinBySymbol = useCallback((symbol: string) => {
    return coins.find(c => c.symbol === symbol.toUpperCase());
  }, [coins]);

  return { 
    coins, 
    loading, 
    getCoinBySymbol 
  };
}

