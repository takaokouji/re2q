import { ApolloClient, InMemoryCache, HttpLink } from '@apollo/client'

const httpLink = new HttpLink({
  uri: 'http://localhost:3000/graphql',
  credentials: 'include', // Cookie-based session management
})

const client = new ApolloClient({
  link: httpLink,
  cache: new InMemoryCache(),
  defaultOptions: {
    watchQuery: {
      fetchPolicy: 'network-only', // For realtime polling
    },
    query: {
      fetchPolicy: 'network-only',
    },
  },
})

export default client
