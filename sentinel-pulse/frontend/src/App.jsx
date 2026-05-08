import { useState, useEffect } from 'react'
import axios from 'axios'

function App() {
  const [results, setResults] = useState([])
  const [voted, setVoted] = useState(false)
  const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

  const fetchResults = async () => {
    try {
      const response = await axios.get(`${API_URL}/results`)
      if (Array.isArray(response.data)) {
        setResults(response.data)
      }
    } catch (error) {
      console.error('Error fetching results:', error)
    }
  }

  useEffect(() => {
    fetchResults()
    const interval = setInterval(fetchResults, 3000)
    return () => clearInterval(interval)
  }, [])

  const castVote = async (candidate) => {
    try {
      await axios.post(`${API_URL}/vote`, { candidate })
      setVoted(true)
      fetchResults()
    } catch (error) {
      console.error('Error casting vote:', error)
    }
  }

  return (
    <div style={{ padding: '20px', fontFamily: 'sans-serif' }}>
      <h1>Sentinel Pulse: Tech Voting</h1>
      <div style={{ display: 'flex', gap: '10px', marginBottom: '20px' }}>
        {['Docker', 'Kubernetes', 'Terraform'].map((tech) => (
          <button 
            key={tech} 
            onClick={() => castVote(tech)}
            style={{ padding: '10px 20px', cursor: 'pointer' }}
          >
            Vote {tech}
          </button>
        ))}
      </div>

      {voted && <p style={{ color: 'green' }}>Thank you for voting!</p>}

      <h2>Live Results</h2>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '5px' }}>
        {results.map((res) => (
          <div key={res.candidate} style={{ background: '#eee', padding: '10px', width: '300px' }}>
            <strong>{res.candidate}:</strong> {res.count} votes
          </div>
        ))}
      </div>
    </div>
  )
}

export default App
