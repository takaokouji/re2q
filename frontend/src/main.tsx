import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { ApolloProvider } from '@apollo/client/react'
import { Provider } from '@/components/ui/provider'
import './index.css'
import App from './App.tsx'
import client from './apolloClient'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <Provider>
      <ApolloProvider client={client}>
        <BrowserRouter basename="/frontend">
          <App />
        </BrowserRouter>
      </ApolloProvider>
    </Provider>
  </StrictMode>,
)
