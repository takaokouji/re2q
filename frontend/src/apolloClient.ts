import { ApolloClient, InMemoryCache, HttpLink } from '@apollo/client'

const getGraphQLEndpoint = () => {
  // 本番環境では同じドメインの /graphql を使用
  if (import.meta.env.PROD) {
    return `${window.location.origin}/graphql`
  }
  // 開発環境ではlocalhost:3000を使用
  return 'http://localhost:3000/graphql'
}

const httpLink = new HttpLink({
  uri: getGraphQLEndpoint(),
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
