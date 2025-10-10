import { useAuth } from "react-oidc-context";
import Dashboard from "./pages/DashBoard";
import LoginPage from './pages/LoginPage';

function App() {
  const auth = useAuth();

  // Se a biblioteca ainda está verificando a sessão, mostre "Loading..."
  if (auth.isLoading) {
    return <div>Loading...</div>;
  }

  // Se houve um erro durante a autenticação
  if (auth.error) {
    return <div>Erro de autenticação: {auth.error.message}</div>;
  }

  // Se o usuário NÃO estiver autenticado, mostre nossa página de login
  if (!auth.isAuthenticated) {
    return <LoginPage />;
  }

  // Se tudo deu certo e o usuário está autenticado, mostre o Dashboard
  return <Dashboard />;
}

export default App;