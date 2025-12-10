import { Routes, Route } from 'react-router-dom'
import { Box } from '@mui/material'
import Layout from './components/Layout'
import Dashboard from './pages/Dashboard'
import UserManagement from './pages/UserManagement'
import TestEnvironment from './pages/TestEnvironment'
import CalendarGenerator from './pages/CalendarGenerator'
import SystemTests from './pages/SystemTests'
import MLScenarioGenerator from './pages/MLScenarioGenerator'

function App() {
  return (
    <Box sx={{ display: 'flex' }}>
      <Layout>
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/users" element={<UserManagement />} />
          <Route path="/test-environment" element={<TestEnvironment />} />
          <Route path="/calendar-generator" element={<CalendarGenerator />} />
          <Route path="/ml-scenario" element={<MLScenarioGenerator />} />
          <Route path="/system-tests" element={<SystemTests />} />
        </Routes>
      </Layout>
    </Box>
  )
}

export default App
