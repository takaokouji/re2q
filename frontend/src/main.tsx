import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { ApolloProvider } from '@apollo/client/react'
import { ChakraProvider, defaultSystem } from "@chakra-ui/react"
import './index.css'
import App from './App.tsx'
import client from './apolloClient'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ChakraProvider value={defaultSystem}>
      <ApolloProvider client={client}>
        <App />
      </ApolloProvider>
    </ChakraProvider>
  </StrictMode>,
)
